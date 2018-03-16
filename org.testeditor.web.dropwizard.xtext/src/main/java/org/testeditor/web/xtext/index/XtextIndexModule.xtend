package org.testeditor.web.xtext.index

import com.google.inject.AbstractModule
import javax.inject.Inject
import org.eclipse.xtext.resource.IContainer
import org.eclipse.xtext.resource.IResourceDescriptionsProvider
import org.eclipse.xtext.resource.containers.ProjectDescriptionBasedContainerManager
import org.eclipse.xtext.web.server.model.IWebResourceSetProvider

class XtextIndexModule extends AbstractModule {

	@Inject ChunkedResourceDescriptionsProvider index

	override protected configure() {
		binder.bind(IResourceDescriptionsProvider).toInstance(index)
		binder.bind(ChunkedResourceDescriptionsProvider).toInstance(index)
		binder.bind(IContainer.Manager).to(ProjectDescriptionBasedContainerManager)
		binder.bind(IWebResourceSetProvider).to(CustomWebResourceSetProvider) // makes sure the XtextWebDocuments get the same resource set as the index uses
	}

}
