/* Copyright Rupert Smith, 2005 to 2008, all rights reserved. */
package com.thesett.auth.services.rest;

import java.security.KeyPair;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.concurrent.TimeUnit;

import javax.ws.rs.Consumes;
import javax.ws.rs.CookieParam;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Cookie;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.NewCookie;
import javax.ws.rs.core.Response;

import com.thesett.auth.dao.AccountDAO;
import com.thesett.auth.model.*;
import com.thesett.util.collections.CollectionUtil;
import com.thesett.util.jersey.UnitOfWorkWithDetach;
import com.thesett.util.security.jwt.JwtUtils;
import com.thesett.util.security.model.JWTAuthenticationToken;
import com.thesett.util.string.StringUtils;

import io.dropwizard.hibernate.UnitOfWork;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiResponse;
import io.swagger.annotations.ApiResponses;

import org.apache.shiro.crypto.RandomNumberGenerator;
import org.apache.shiro.crypto.SecureRandomNumberGenerator;
import org.infinispan.Cache;

/**
 * AuthResource provides authentication end-points, and supplies JWT tokens in response to valid requests.
 *
 * <pre><p/><table id="crc"><caption>CRC Card</caption>
 * <tr><th> Responsibilities <th> Collaborations
 * <tr><td> Authenticate Users </td></tr>
 * <tr><td> Refresh Logins </td></tr>
 * <tr><td> Logout Users </td></tr>
 * </table></pre>
 *
 * @author Rupert Smith
 */
@Path("/auth/")
@Api(value = "/auth/", description = "API for handling authentication requests.")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(value = MediaType.APPLICATION_JSON)
public class AuthResource
{
    /** Status code to respond to failed logins with. */
    public static final Response UNAUTHORIZED = Response.status(401).build();

    /** An asymmetric crypto kay pair for creating and checking tokens. */
    private final KeyPair keyPair;

    /** The account DAO for verifying logins against. */
    private final AccountDAO accountDAO;

    /** The password hasher. */
    private final PasswordHasherSha256 passwordHasher = new PasswordHasherSha256(1000);

    /** The login token TTL till it expires. */
    private final long jwtTTLMillis;

    /** The refresh token TTL till it expires. */
    private final long refreshTTLMillis;

    /** The refresh cache. */
    private final Cache<String, Account> refreshCache;

    /** A secure random number generator for refresh tokens. */
    private RandomNumberGenerator random;

    /**
     * Creates a set of authentication end-points, against the accounts accessible through the specified accounts DAO.
     *
     * @param accountDAO       The accounts DAO, to verify user accounts against.
     * @param keyPair          An asymmetric crypto kay pair for creating and checking tokens.
     * @param jwtTTLMillis     The login token TTL till it expires.
     * @param refreshTTLMillis The refresh token TTL till it expires.
     * @param refreshCache     The refresh cache.
     */
    public AuthResource(AccountDAO accountDAO, KeyPair keyPair, long jwtTTLMillis, long refreshTTLMillis,
        Cache<String, Account> refreshCache)
    {
        this.accountDAO = accountDAO;
        this.keyPair = keyPair;
        this.jwtTTLMillis = jwtTTLMillis;
        this.refreshTTLMillis = refreshTTLMillis;
        this.refreshCache = refreshCache;
        random = new SecureRandomNumberGenerator();
    }

    /**
     * Authenticates a user by username and password. If the request is successful a JWT token is returned as an
     * 'httpOnly' cookie. The JWT token will contain the username as subject, and the users roles as valid claims. The
     * token is also returned in the body, as it can be useful for a front-end to customize itself based on what rights
     * a user has.
     *
     * @param  authRequest The username/password authentication request.
     *
     * @return A response with the JWT as an httpOnly cookie, and in the body, or the {@link #UNAUTHORIZED} return code
     *         when the login is not accepted.
     */
    @POST
    @Path("/login")
    @UnitOfWork
    @ApiOperation(value = "Authenticates a user by username and password.")
    @ApiResponses(
        value =
            {
                @ApiResponse(code = 200, message = "Success.", response = String.class),
                @ApiResponse(code = 401, message = "User not authenticated.")
            }
    )
    public Response login(AuthRequest authRequest)
    {
        // Check the request against the accounts.
        Account account =
            CollectionUtil.first(accountDAO.findByExample(new Account().withUsername(authRequest.getUsername())));

        if (account == null)
        {
            return UNAUTHORIZED;
        }

        if (!passwordHasher.checkHash(authRequest.getPassword(), account.getPassword(), account.getSalt()))
        {
            return UNAUTHORIZED;
        }

        // Extract the users permissions into a description of their access claims.
        Set<String> permissions = new LinkedHashSet<>();

        if (account.getRoles() != null)
        {
            for (Role role : account.getRoles())
            {
                if (role.getPermissions() != null)
                {
                    for (Permission permission : role.getPermissions())
                    {
                        permissions.add(permission.getName());
                    }
                }
            }
        }

        // Generate a refresh token and stuff it in the refresh cache.
        String refreshToken = random.nextBytes().toBase64();
        refreshCache.put(refreshToken, account, refreshTTLMillis, TimeUnit.MILLISECONDS);

        // Create the JWT token with claims matching the account, as a cookie.
        String token = JwtUtils.createToken(account.getUsername(), permissions, keyPair.getPrivate(), jwtTTLMillis);
        NewCookie cookie =
            new NewCookie("jwt", token, "/", "localhost", "jwt", (int) (jwtTTLMillis / 1000), false, true);

        AuthResponse authResponse = new AuthResponse().withToken(token).withRefreshToken(refreshToken);
        Response response = Response.ok().cookie(cookie).entity(authResponse).build();

        return response;
    }

    /**
     * Refreshes the callers JWT token, provided they are currently logged in with a valid token.
     *
     * @param  cookie The callers JWT token cookie.
     *
     * @return <tt>true</tt> iff the caller has a currently valid token.
     */
    @GET
    @Path("/refresh")
    @UnitOfWorkWithDetach
    @ApiOperation(value = "Checks if a user token is authenticated.")
    public Response refresh(@CookieParam(value = "jwt") Cookie cookie)
    {
        System.out.println("cookie = " + cookie);

        if (cookie == null)
        {
            return UNAUTHORIZED;
        }

        String token = cookie.getValue();

        if (!StringUtils.nullOrEmpty(token))
        {
            // Extract the current token and check it is valid.
            JWTAuthenticationToken authenticationToken = new JWTAuthenticationToken(token);
            authenticationToken.setPublicKey(keyPair.getPublic());

            if (!authenticationToken.checkValid())
            {
                return UNAUTHORIZED;
            }

            authenticationToken.extractClaims();

            // Build a new token with the same claims as the existing one.
            String refreshToken =
                JwtUtils.createToken(authenticationToken.getSubject(), authenticationToken.getPermissions(),
                    keyPair.getPrivate(), jwtTTLMillis);
            NewCookie refreshCookie =
                new NewCookie("jwt", refreshToken, "/", "localhost", "jwt", (int) (jwtTTLMillis / 1000), false, true);

            Response response =
                Response.ok().cookie(refreshCookie).entity(new AuthResponse().withToken(refreshToken)).build();

            return response;
        }
        else
        {
            return UNAUTHORIZED;
        }
    }

    /**
     * Removes the callers JWT token cookie.
     *
     * @return An OK response, with a JWT cookie set to expire in the past.
     */
    @POST
    @Path("/logout")
    @UnitOfWorkWithDetach
    @ApiOperation(value = "Removes the authentication cookie.")
    public Response logout()
    {
        return Response.ok()
            .header("Set-Cookie", "jwt=deleted;Domain=localhost;Path=/;Expires=Thu, 01-Jan-1970 00:00:01 GMT")
            .build();
    }
}
