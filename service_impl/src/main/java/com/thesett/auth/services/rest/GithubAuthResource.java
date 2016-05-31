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
    private final ClientSecretsConfiguration secrets;

    private final Client client;

    public GithubAuthResource(ClientSecretsConfiguration secrets, Client client)
    {
        this.secrets = secrets;
        this.client = client;
    }

    @POST
    @Path("github")
    @UnitOfWork
    @Consumes(MediaType.APPLICATION_JSON)
    public Response login(Payload payload, @Context HttpServletRequest request)
    {
        String accessTokenUrl = "https://github.com/login/oauth/access_token";

        Response response;

        // Exchange authorization code for access token.
        response =
            client.target(accessTokenUrl).queryParam(CLIENT_ID_KEY, payload.getClientId()).queryParam(REDIRECT_URI_KEY,
                payload.getRedirectUri()).queryParam(CLIENT_SECRET, secrets.getGithub()).queryParam(CODE_KEY,
                payload.getCode()).request("text/plain").accept(MediaType.APPLICATION_JSON).get();

        Map<String, Object> responseEntity = getResponseEntity(response);

        // Extract information about the user.

        // Process the authenticated user.
        return Response.ok().build();
    }
}