package org.testeditor.web.xtext.index

import com.google.inject.Provider
import javax.inject.Inject
import javax.inject.Singleton
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.web.server.IServiceContext
import org.eclipse.xtext.web.server.model.IWebResourceSetProvider

@Singleton
class CustomWebResourceSetProvider implements IWebResourceSetProvider {

	@Inject Provider<XtextResourceSet> resourceSetProvider
	@Inject ChunkedResourceDescriptionsProvider resourceDescriptionsProvider

	override get(String resourceId, IServiceContext serviceContext) {
		val resourceSet = resourceSetProvider.get

		// cannot return indexProvider.indexResourceSet, since concurrent service requests (e.g. occurrences) may 
		// modify this resource set resulting in inconsistent results.
		// class path context must be shared however, in order to allow cross references to compiled java resources!
		resourceSet.classpathURIContext = resourceDescriptionsProvider.indexResourceSet.classpathURIContext
		resourceDescriptionsProvider.project.attachToEmfObject(resourceSet)

		return resourceSet
	}
}
