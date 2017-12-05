package org.testeditor.web.xtext.index.resources

import javax.ws.rs.Consumes
import javax.ws.rs.POST
import javax.ws.rs.Produces
import javax.ws.rs.QueryParam
import javax.ws.rs.core.Response

interface GlobalScopeResource {

	/**
	 * Gets all elements in the scope for a given reference, viewed from the
	 * provided context resource.
	 * 
	 * This method exposes a REST endpoint for Xtext's global scope provision
	 * mechanism, to be invoked via HTTP POST. Implementations may delegate the
	 * request to Xtext standard global scope provider implementations, such as 
	 * @link{org.eclipse.xtext.scoping.impl.DefaultGlobalScopeProvider DefaultGlobalScopeProvider}.
	 * The result is returned as a list of 
	 * @link{org.eclipse.xtext.resource.IEObjectDescription IEObjectDescription};
	 * the caller is responsible for wrapping them into an 
	 * @link{org.eclipse.xtext.scoping.IScope IScope} object, if required.
	 * Individual IEObjectDescription objects are transmitted serialized to JSON
	 * in the following format (example description of an instance of class
	 * @link{org.eclipse.xtext.Grammar Grammar}):
	 * 
	 *   {
	 *     "eObjectURI" : "#//",
	 *     "uri" : "http://www.eclipse.org/2008/Xtext#//Grammar",
	 *     "fullyQualifiedName" : "sampleEObject"
	 *   }
	 * 
	 * @param context The complete content of the resource (file) from where the
	 * scope is looked at. Optional. Transmitted as plain-text in the body of the request.
	 * @param contentType The content type of the context resource. This is optional
	 * if the content type can be determined from the context URI (file extension).
	 * Transmitted as query parameter "contentType".
	 * @param contextURI The URI of the context resource. This must be a valid URI name, but
	 * not necessarily a resolvable locator. The file extension should match the resource's
	 * content type, if applicable. Transmitted as query parameter "contextURI".
	 * @param eReferenceURIString The URI of the EReference for which all
	 * potential targets in the scope are to be retrieved. Transmitted as query
	 * parameter "reference".
	 * @returns a list of all IEObjectDescription elements that are in the scope
	 * viewed from the specified context, and are target candidates for the
	 * given reference. Transmitted as JSON in the body of the response.
	 */
	@POST
	@Consumes("text/plain")
	@Produces("application/json")
	def Response getScope(String context, @QueryParam("contentType") String contentType,
		@QueryParam("contextURI") String contextURI, @QueryParam("reference") String eReferenceURIString)
}
