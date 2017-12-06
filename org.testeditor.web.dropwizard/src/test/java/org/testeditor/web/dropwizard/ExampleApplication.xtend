package org.testeditor.web.dropwizard

import io.dropwizard.setup.Environment
import javax.inject.Inject
import javax.ws.rs.GET
import javax.ws.rs.Path
import javax.ws.rs.Produces
import javax.ws.rs.core.MediaType
import javax.ws.rs.core.Response
import org.testeditor.web.dropwizard.auth.ApiTokenAuth
import org.testeditor.web.dropwizard.auth.NoAuth
import org.testeditor.web.dropwizard.auth.User

import static javax.ws.rs.core.Response.Status.*
import static javax.ws.rs.core.Response.status

class ExampleApplication extends DropwizardApplication<ExampleConfiguration> {

	override run(ExampleConfiguration configuration, Environment environment) throws Exception {
		super.run(configuration, environment)
		environment.jersey => [
			register(RestrictedByDefaultResource)
			register(ApiTokenRestrictedByDefaultResource)
			register(NoAuthResource)
			register(NoAuthOnMethodResource)
			register(UserResource)
		]
	}

	@NoAuth
	@Path("/noauth-on-class")
	@Produces(MediaType.TEXT_PLAIN)
	public static class NoAuthResource {

		@GET
		def Response load() {
			return status(OK).entity("Hello, universe!").build
		}

	}

	@Path("/noauth-on-method")
	@Produces(MediaType.TEXT_PLAIN)
	public static class NoAuthOnMethodResource {

		@NoAuth
		@GET
		def Response load() {
			return status(OK).entity("Hello, milkyway!").build
		}

	}

	@Path("/protected-resource")
	@Produces(MediaType.TEXT_PLAIN)
	public static class RestrictedByDefaultResource {

		@GET
		def Response load() {
			return status(OK).entity("Hello, world!").build
		}

	}

	@Path("/api-token-protected-resource")
	@Produces(MediaType.TEXT_PLAIN)
	public static class ApiTokenRestrictedByDefaultResource {

		@GET
		@ApiTokenAuth
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
