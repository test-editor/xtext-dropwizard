package org.testeditor.web.dropwizard.xtext.validation

import java.util.concurrent.TimeoutException
import javax.inject.Inject
import javax.inject.Provider
import javax.servlet.http.HttpServletRequest
import javax.ws.rs.DefaultValue
import javax.ws.rs.GET
import javax.ws.rs.Path
import javax.ws.rs.Produces
import javax.ws.rs.QueryParam
import javax.ws.rs.container.AsyncResponse
import javax.ws.rs.container.Suspended
import javax.ws.rs.core.Context
import javax.ws.rs.core.MediaType
import javax.ws.rs.core.Response.ResponseBuilder
import org.glassfish.jersey.server.ManagedAsync

import static javax.ws.rs.core.Response.Status.NO_CONTENT
import static javax.ws.rs.core.Response.Status.OK

@Path('validation-markers')
class ValidationMarkerResource {

	@Inject ValidationMarkerMap markerMap
	@Inject Provider<ResponseBuilder> responseBuilderProvider
	@Context HttpServletRequest request

	private static val LONG_POLLING_TIMEOUT_MILLIS = 4000

	@GET
	@Produces(MediaType.APPLICATION_JSON)
	def getValidationMarkers(@QueryParam('resource') String resourcePath) {
		if (resourcePath === null) {
			return markerMap.allMarkers
		} else {
			return #[markerMap.getMarker(resourcePath)]
		}
	}

	@GET
	@Path('updates')
	@Produces(MediaType.APPLICATION_JSON)
	@ManagedAsync
	def void waitForValidationUpdates(@Suspended AsyncResponse response, @DefaultValue('-1') @QueryParam('lastAccessed') long lastAccessed) {
		try {
			val markers = markerMap.waitForUpdatedMarkers(lastAccessed, LONG_POLLING_TIMEOUT_MILLIS)
			response.resume(
				responseBuilderProvider.get.status(OK).entity(markers).header('lastAccessed', System.currentTimeMillis).build
			)
		} catch (TimeoutException ex) {
			response.resume(
				responseBuilderProvider.get.status(NO_CONTENT).header('lastAccessed', System.currentTimeMillis).build
			)
		}
	}

}
