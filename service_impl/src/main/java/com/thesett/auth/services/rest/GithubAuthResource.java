/* Copyright Rupert Smith, 2005 to 2008, all rights reserved. */
package com.thesett.auth.services.rest;

import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.Consumes;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.client.Client;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import com.thesett.auth.services.config.ClientSecretsConfiguration;
import com.thesett.util.jackson.JacksonUtils;
import com.thesett.util.security.shiro.ShiroUtils;

import io.dropwizard.hibernate.UnitOfWork;

/**
 * <pre><p/><table id="crc"><caption>CRC Card</caption>
 * <tr><th> Responsibilities <th> Collaborations
 * <tr><td>
 * </table></pre>
 *
 * @author Rupert Smith
 */
@Path("/auth/")
public class GithubAuthResource extends OAuthProviderResource
{
    public GithubAuthResource(ClientSecretsConfiguration secrets, Client client)
    {
        super(secrets, client);
    }

    @POST
    @Path("github")
    @UnitOfWork
    @Consumes(MediaType.APPLICATION_JSON)
    public Response login(Payload payload, @Context HttpServletRequest request)
    {
        String accessTokenUrl = "https://github.com/login/oauth/access_token";
        String userApiUrl = "https://api.github.com/user";

        Response response;

        // Exchange authorization code for access token.
        response =
            client.target(accessTokenUrl).queryParam(CLIENT_ID_KEY, payload.getClientId()).queryParam(REDIRECT_URI_KEY,
                payload.getRedirectUri()).queryParam(CLIENT_SECRET, secrets.getGithub()).queryParam(CODE_KEY,
                payload.getCode()).request("text/plain").accept(MediaType.APPLICATION_JSON).get();

        Map<String, Object> responseEntity = JacksonUtils.getResponseEntity(response);

        // Extract information about the user.
        String accessToken = (String) responseEntity.get("access_token");
        response =
            client.target(userApiUrl).request("text/plain").accept(MediaType.APPLICATION_JSON).header(AUTH_HEADER_KEY,
                String.format("Bearer %s", accessToken)).get();

        Map<String, Object> userInfo = JacksonUtils.getResponseEntity(response);

        try
        {
            setupShiroSubjectByJWTToken(request, null);

            // Process the authenticated the user.
            processUser(Provider.GITHUB, userInfo.get("id").toString(), userInfo.get("name").toString());
        }
        finally
        {
            ShiroUtils.clearSubject();
        }

        return Response.status(Response.Status.OK).build();
    }
}
