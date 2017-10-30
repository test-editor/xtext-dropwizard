package org.testeditor.web.dropwizard

import io.dropwizard.setup.Environment
import javax.inject.Inject
import javax.ws.rs.GET
import javax.ws.rs.Path
import javax.ws.rs.Produces
import javax.ws.rs.core.MediaType
import javax.ws.rs.core.Response
import org.testeditor.web.dropwizard.auth.User

import static javax.ws.rs.core.Response.Status.*
import static javax.ws.rs.core.Response.status

class ExampleApplication extends DropwizardApplication<ExampleConfiguration> {

    override run(ExampleConfiguration configuration, Environment environment) throws Exception {
        super.run(configuration, environment)
        environment.jersey => [
            register(HelloWorldResource)
            register(UserResource)
        ]
    }

    @Path("/helloworld")
    @Produces(MediaType.TEXT_PLAIN)
    public static class HelloWorldResource {

        @GET
        def Response load() {
            return status(OK).entity("Hello, world!").build
        }

    }

    @Path("/user")
    @Produces(MediaType.APPLICATION_JSON)
    public static class UserResource {

        @Inject User user

        @GET
        def User get() {
            return user
        }

    }

}
