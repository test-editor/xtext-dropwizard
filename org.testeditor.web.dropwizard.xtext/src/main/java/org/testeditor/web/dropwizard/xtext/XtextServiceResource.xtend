package org.testeditor.web.dropwizard.xtext

import com.google.inject.Injector
import javax.inject.Inject
import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse
import javax.ws.rs.Consumes
import javax.ws.rs.GET
import javax.ws.rs.POST
import javax.ws.rs.PUT
import javax.ws.rs.Path
import javax.ws.rs.PathParam
import javax.ws.rs.core.CacheControl
import javax.ws.rs.core.Context
import javax.ws.rs.core.MediaType
import javax.ws.rs.core.MultivaluedMap
import javax.ws.rs.core.Response
import javax.ws.rs.core.UriInfo
import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.web.server.IServiceContext
import org.eclipse.xtext.web.server.IUnwrappableServiceResult
import org.eclipse.xtext.web.server.InvalidRequestException
import org.eclipse.xtext.web.server.InvalidRequestException.InvalidDocumentStateException
import org.eclipse.xtext.web.server.InvalidRequestException.PermissionDeniedException
import org.eclipse.xtext.web.server.InvalidRequestException.ResourceNotFoundException
import org.eclipse.xtext.web.server.InvalidRequestException.UnknownLanguageException
import org.eclipse.xtext.web.server.XtextServiceDispatcher
import org.eclipse.xtext.web.server.XtextServiceDispatcher.ServiceDescriptor
import org.eclipse.xtext.web.servlet.XtextServlet
import org.slf4j.LoggerFactory
import org.testeditor.web.xtext.index.LanguageAccessRegistry

import static java.util.concurrent.TimeUnit.NANOSECONDS

/**
 * Adapted from {@link XtextServlet}.
 */
@Path("xtext-service/{serviceType}")
class XtextServiceResource {

	static val logger = LoggerFactory.getLogger(XtextServiceResource)

	@Inject LanguageAccessRegistry languages

	@Context UriInfo ui
	@Context HttpServletRequest request
	@PathParam("serviceType") String serviceType

	@GET
	def Response doGet() {
		val serviceContext = new XtextServiceContext(serviceType, request, ui.queryParameters)
		return service(serviceContext)
	}

	@POST
	@Consumes(MediaType.APPLICATION_FORM_URLENCODED)
	def Response doPost(MultivaluedMap<String, String> formParams) {
		val serviceContext = new XtextServiceContext(serviceType, request, ui.queryParameters, formParams)
		return service(serviceContext)
	}

	/** 
	 * Never called in stateless mode (sendFullText = true on client-side).
	 */
	@PUT
	@Consumes(MediaType.APPLICATION_FORM_URLENCODED)
	def Response doPut(MultivaluedMap<String, String> formParams) {
		val serviceContext = new XtextServiceContext(serviceType, request, ui.queryParameters, formParams)
		return service(serviceContext)
	}

	private def Response service(IServiceContext context) {
		val enterAt = System.nanoTime
		logger.info('Received request: {} {}', request.method, request.requestURI)
		val service = getService(context)
		var Response result
		try {
			result = doService(service)
		} catch (Exception exception) {
			result = handleServiceError(exception)
		}
		
		val duration = NANOSECONDS.toMillis(System.nanoTime - enterAt)
		logger.info('Done processing request: {} ({} ms)', request.requestURI, duration)
		return result
	}

	private def Response handleServiceError(Exception exception) {
		val status = switch (exception) {
			ResourceNotFoundException:
				HttpServletResponse.SC_NOT_FOUND
			InvalidDocumentStateException:
				HttpServletResponse.SC_CONFLICT
			PermissionDeniedException:
				HttpServletResponse.SC_FORBIDDEN
			InvalidRequestException:
				HttpServletResponse.SC_BAD_REQUEST
			default: {
				logger.info('Unhandled exception during request ({}): {}', request.requestURI, exception.message)
				throw exception
			}
		}
		logger.info('Invalid request ({}): {}', request.requestURI, exception.message)
		return Response.status(status).entity(exception.message).build
	}

	private def ServiceDescriptor getService(IServiceContext serviceContext) {
		val injector = this.getInjector(serviceContext)
		val serviceDispatcher = injector.getInstance(XtextServiceDispatcher)
		val service = serviceDispatcher.getService(serviceContext)
		return service
	}

	private def Response doService(XtextServiceDispatcher.ServiceDescriptor service) {
		val result = service.service.apply
		val builder = Response.ok => [
			encoding('UTF-8')
			cacheControl(CacheControl.valueOf('no-cache'))
		]
		if (result instanceof IUnwrappableServiceResult && (result as IUnwrappableServiceResult).content !== null) {
			val unwrapResult = result as IUnwrappableServiceResult
			builder.entity(unwrapResult.content).type(unwrapResult.contentType ?: MediaType.TEXT_PLAIN)
		} else {
			builder.entity(result).type(MediaType.APPLICATION_JSON)
		}
		return builder.build
	}

	/**
	 * Copied from super class, Xtext should really expect IServiceContext as a parameter, not HttpServiceContext
	 * make use of language access provided by standalone builder
	 */
	protected def Injector getInjector(IServiceContext serviceContext) throws UnknownLanguageException {
		val emfURI = URI.createURI(serviceContext.getParameter('resource') ?: '')
		val contentType = serviceContext.getParameter('contentType')

		val fileExtension = contentType ?: emfURI.fileExtension
		val languageAccess = languages.getAccess(fileExtension)
		if (languageAccess === null) {
			if (!contentType.nullOrEmpty) {
				throw new UnknownLanguageException('''Unable to identify the Xtext language for contentType «contentType».''')
			} else if (!emfURI.toString.empty) {
				throw new UnknownLanguageException('''Unable to identify the Xtext language for resource «emfURI».''')
			} else {
				throw new UnknownLanguageException('''Unable to identify the Xtext language: missing parameter 'resource' or 'contentType'.''')
			}
		}
		return languageAccess.resourceServiceProvider.get(Injector)
	}

}
