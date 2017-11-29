package org.testeditor.web.dropwizard.testing

import io.dropwizard.Application
import io.dropwizard.setup.Environment
import javax.ws.rs.GET
import javax.ws.rs.Path
import javax.ws.rs.Produces
import javax.ws.rs.core.MediaType
import javax.ws.rs.core.Response

import static javax.ws.rs.core.Response.Status.*
import static javax.ws.rs.core.Response.status

class ExampleApplication extends Application<ExampleConfiguration> {

	override run(ExampleConfiguration configuration, Environment environment) throws Exception {
		environment.jersey => [
			register(HelloWorldResource)
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

}
