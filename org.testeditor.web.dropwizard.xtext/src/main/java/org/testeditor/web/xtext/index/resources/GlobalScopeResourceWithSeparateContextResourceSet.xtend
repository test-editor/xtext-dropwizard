package org.testeditor.web.xtext.index.resources

import java.io.IOException
import javax.inject.Inject
import javax.inject.Provider
import javax.ws.rs.Consumes
import javax.ws.rs.POST
import javax.ws.rs.Path
import javax.ws.rs.Produces
import javax.ws.rs.QueryParam
import javax.ws.rs.core.MediaType
import javax.ws.rs.core.Response
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.scoping.IGlobalScopeProvider
import org.eclipse.xtext.util.StringInputStream
import org.slf4j.LoggerFactory
import org.testeditor.web.xtext.index.resources.exceptions.InvalidEReferenceException

@Path("/xtext/index/global-scope")
@Produces(MediaType.APPLICATION_JSON)
class GlobalScopeResourceWithSeparateContextResourceSet implements GlobalScopeResource {

	protected static val logger = LoggerFactory.getLogger(GlobalScopeResourceWithSeparateContextResourceSet)

	@Inject IGlobalScopeProvider globalScopeProvider
	@Inject Provider<ResourceSet> resourceSetProvider

	@POST // to allow context content to be passed as payload (instead of using query parameters)
	@Consumes("text/plain")
	@Produces("application/json")
	override Response getScope(String context, @QueryParam("contentType") String contentType,
		@QueryParam("contextURI") String contextURI, @QueryParam("reference") String eReferenceURIString) {

		val eReference = createEReference(eReferenceURIString)
		val resource = createContextResource(context, contextURI, contentType)

		val scope = globalScopeProvider.getScope(resource, eReference, null).allElements
		logger.debug("Global scope provider returned the following elements='{}'", scope.map[name])

		return Response.ok(scope.toList).build
	}

	private def createContextResource(String context, String contextURI, String contentType) {
		logger.debug("Trying to retrieve or create context resource type='{}', URI='{}'", contentType, contextURI)
		val resourceSet = resourceSetProvider.get // using empty resource set, since context will be used for this request only and is not part of the index
		val resource = getOrCreateResource(resourceSet, contextURI, contentType)
		if (!context.nullOrEmpty) {
			loadResource(resource, context)
		}
		return resource
	}

	private def Resource getOrCreateResource(ResourceSet resourceSet, String contextURI, String contentType) {
		val uri = URI.createURI(contextURI)
		return resourceSet.getResource(uri, false) ?: resourceSet.createResource(uri, contentType)
	}

	private def loadResource(Resource resource, String context) {
		try {
			resource.load(new StringInputStream(context), emptyMap)
		} catch (IOException e) {
			val message = '''Failed to load provided content into resource «IF (resource !== null)»(URI: «resource.URI»)«ELSE» (resource is null!)«ENDIF»'''
			logger.warn(message, e)
		}

	}

	private def createEReference(String eReferenceURIString) {
		logger.debug("Trying to instantiate EReference from URI string='{}'", eReferenceURIString)
		val eReferenceURI = createURI(eReferenceURIString)
		val baseURIString = eReferenceURI.trimFragment().toString()
		val ePackage = retrieveEPackage(baseURIString)

		return loadEReferenceFromEPackageResource(ePackage, eReferenceURI)
	}

	private def createURI(String eReferenceURIString) {
		try {
			return URI.createURI(eReferenceURIString)
		} catch (IllegalArgumentException e) {
			throw new InvalidEReferenceException('''Provided EReference URI is invalid: «eReferenceURIString»''', e)
		}
	}

	private def retrieveEPackage(String baseURIString) {
		val ePackage = EPackage.Registry.INSTANCE.getEPackage(baseURIString)
		if (ePackage === null) {
			throw new InvalidEReferenceException('''Failed to load EPackage for URI: «baseURIString»''')
		} else if (ePackage.eResource === null) {
			throw new InvalidEReferenceException('''Containing resource for EPackage not found (URI: «baseURIString»)''')
		} else {
			return ePackage
		}
	}

	private def loadEReferenceFromEPackageResource(EPackage ePackage, URI eReferenceURI) {
		if (eReferenceURI.hasFragment) {
			val eReference = ePackage.eResource.getEObject(eReferenceURI.fragment) as EReference
			logger.debug("Successfully instantiated EReference name='{}', type='{}'", eReference.name,
				eReference.EReferenceType.name)
			return eReference
		} else {
			throw new InvalidEReferenceException('''Provided EReference URI does not point at concrete EObject (fragment is missing): «eReferenceURI.toString»''')
		}
	}

}
