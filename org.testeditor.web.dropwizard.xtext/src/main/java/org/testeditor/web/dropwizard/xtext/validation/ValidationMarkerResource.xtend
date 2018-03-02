package org.testeditor.web.dropwizard.xtext.validation

import java.util.concurrent.TimeoutException
import javax.inject.Inject
import javax.inject.Provider
import javax.ws.rs.DefaultValue
import javax.ws.rs.GET
import javax.ws.rs.Path
import javax.ws.rs.Produces
import javax.ws.rs.QueryParam
import javax.ws.rs.container.AsyncResponse
import javax.ws.rs.container.Suspended
import javax.ws.rs.core.MediaType
import javax.ws.rs.core.Response.ResponseBuilder
import org.glassfish.jersey.server.ManagedAsync

import static javax.ws.rs.core.Response.Status.NO_CONTENT
import static javax.ws.rs.core.Response.Status.OK

@Path('validation-markers')
class ValidationMarkerResource {

	@Inject ValidationMarkerMap markerMap
	@Inject Provider<ResponseBuilder> responseBuilderProvider

	private static val LONG_POLLING_TIMEOUT_MILLIS = 4000

	@GET
	@Produces(MediaType.APPLICATION_JSON)
	def Iterable<ValidationSummary> getValidationMarkers(@QueryParam('resource') String resourcePath) {
		if (resourcePath === null) {
			return markerMap.allMarkers
		} else {
			return #[markerMap.getMarker(resourcePath)]
		}
	}

	/**
	 * Retrieve all validation markers, potentially waiting for updates to occur.
	 * 
	 * This is intended to be used for long-polling, i.e. clients keep sending
	 * requests in an effort to be notified as soon as updated validation
	 * markers become available. If the validation markers were updated since
	 * the time the client reports it last accessed them, or if the client did
	 * not provide that information, the request will be responded to
	 * immediately. Otherwise, the response will be delayed until either a
	 * timeout occurs, or the validation markers do get updated. In the former
	 * case, the response will be empty with status code 204 "NO_CONTENT", in
	 * the latter case, the response will contain all validation markers with
	 * status code 200 "OK".
	 * In any case, the response will contain the time stamp the last access
	 * occurred in the header field "lastAccessed", which can be used in a 
	 * subsequent request.
	 */
	@GET
	@Path('updates')
	@Produces(MediaType.APPLICATION_JSON)
	@ManagedAsync
	def void waitForValidationUpdates(@Suspended AsyncResponse response, @DefaultValue('-1') @QueryParam('lastAccessed') long lastAccessed) {
		val timeBeingAccessed = System.currentTimeMillis
		try {
			val markers = markerMap.waitForAnyNewMarkersSince(lastAccessed, LONG_POLLING_TIMEOUT_MILLIS)
			response.resume(
				responseBuilderProvider.get.status(OK).entity(markers).header('lastAccessed', timeBeingAccessed).build
			)
		} catch (TimeoutException ex) {
			response.resume(
				responseBuilderProvider.get.status(NO_CONTENT).header('lastAccessed', timeBeingAccessed).build
			)
		}
	}

}
