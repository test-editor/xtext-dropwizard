package org.testeditor.web.dropwizard

import javax.inject.Inject
import javax.ws.rs.GET
import javax.ws.rs.Path
import javax.ws.rs.Produces
import javax.ws.rs.QueryParam
import javax.ws.rs.core.MediaType
import javax.ws.rs.core.Response

import static javax.ws.rs.core.Response.Status.*
import static javax.ws.rs.core.Response.status

@Path("/versions")
@Produces(MediaType.APPLICATION_JSON)
class BuildVersionResource {

	DropwizardApplicationConfiguration configuration
	@Inject BuildVersionProvider buildVersionProvider
	
	new(DropwizardApplicationConfiguration configuration) {
		this.configuration = configuration
	}

	@GET
	@Path("/all")
	def Response getVersions(@QueryParam("dependency") String dependency) {
		return status(OK).entity(buildVersionProvider.getDependencies(configuration, dependency).toList).build
	}

	@GET
	@Path("/testeditor")
	def Response getTesteditorVersions(@QueryParam("dependency") String dependency) {
		return status(OK).entity(buildVersionProvider.getTesteditorDependencies(configuration, dependency).toList).build
	}

}
