package org.testeditor.web.xtext.index

import javax.inject.Singleton
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.web.server.IServiceContext
import org.eclipse.xtext.web.server.model.IWebResourceSetProvider

@Singleton
class CustomWebResourceSetProvider implements IWebResourceSetProvider {

	val XtextIndex index

	new(XtextIndex newIndex) {
		index = newIndex
	}

	override get(String resourceId, IServiceContext serviceContext) {
		val result = new XtextResourceSet
		result.classpathURIContext = (index.resourceSet as XtextResourceSet).classpathURIContext

		return result 
		// cannot return index.resourceSet, since concurrent service requests (e.g. occurrences) may modify this resource set 
		// resulting in inconsistent results.
		// class path context must be shared however, in order to allow cross references to compiled java resources!
	}

}
