package org.testeditor.web.xtext.index

import javax.inject.Inject
import javax.ws.rs.GET
import javax.ws.rs.POST
import javax.ws.rs.Path
import javax.ws.rs.Produces
import javax.ws.rs.core.MediaType
import javax.ws.rs.core.Response

import static javax.ws.rs.core.Response.Status.*
import static javax.ws.rs.core.Response.status

@Path("index")
class IndexResource {

	@Inject BuildCycleManager buildManager
	@Inject ChunkedResourceDescriptionsProvider resourceDescriptionsProvider

	@Path("refresh")
	@POST
	def Response refresh(String payload) {
		buildManager.startBuild
		return status(NO_CONTENT).build
	}
	
	@Path("exported-objects")
	@GET
	@Produces(MediaType.APPLICATION_JSON)
	def Iterable<String> getExportedObjects() {
		return resourceDescriptionsProvider.data.exportedObjects.map[name.toString]
	}

}
