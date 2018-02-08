package org.testeditor.web.xtext.index

import org.eclipse.xtext.web.server.model.IWebResourceSetProvider
import org.eclipse.xtext.web.server.IServiceContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CustomWebResourceSetProvider implements IWebResourceSetProvider {
	
	var XtextIndex index
	
	def void initWith(XtextIndex newIndex) {
		index = newIndex
	}
	
	override get(String resourceId, IServiceContext serviceContext) {
		return index.resourceSet
	}
	
}