package org.testeditor.web.xtext.index

import javax.inject.Inject
import javax.ws.rs.POST
import javax.ws.rs.Path
import javax.ws.rs.core.Response

import static javax.ws.rs.core.Response.Status.*
import static javax.ws.rs.core.Response.status

@Path("index")
class IndexResource {

	@Inject BuildCycleManager buildManager

	@Path("refresh")
	@POST
	def Response refresh(String payload) {
		buildManager.startBuild
		return status(NO_CONTENT).build
	}

	@Path("reload")
	@POST
	def Response reload(String payload) {
		buildManager.startRebuild
		return status(NO_CONTENT).build
	}

}
