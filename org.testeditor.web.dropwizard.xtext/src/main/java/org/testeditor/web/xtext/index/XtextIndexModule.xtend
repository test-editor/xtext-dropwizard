package org.testeditor.web.xtext.index

import com.google.inject.AbstractModule
import javax.inject.Inject
import org.eclipse.xtext.builder.standalone.compiler.EclipseJavaCompiler
import org.eclipse.xtext.builder.standalone.compiler.IJavaCompiler
import org.eclipse.xtext.generator.AbstractFileSystemAccess
import org.eclipse.xtext.generator.JavaIoFileSystemAccess
import org.eclipse.xtext.resource.IContainer
import org.eclipse.xtext.resource.IResourceDescriptionsProvider
import org.eclipse.xtext.resource.containers.ProjectDescriptionBasedContainerManager
import org.eclipse.xtext.web.server.model.IWebResourceSetProvider

class XtextIndexModule extends AbstractModule {

	@Inject ChunkedResourceDescriptionsProvider resourceDescriptionsProvider

	override protected configure() {
		binder.bind(IResourceDescriptionsProvider).toInstance(resourceDescriptionsProvider)
		binder.bind(ChunkedResourceDescriptionsProvider).toInstance(resourceDescriptionsProvider)
		// IncrementalBuilder uses ChunkedResourceDescriptions, which in turn is used by ProjectDescriptionBasedContainerManager.
		// The Xtext service relies on org.eclipse.xtext.resource.IResourceServiceProvider, which depends on a
		// org.eclipse.xtext.resource.IContainer.Manager. Our own ChunkedResourceDescriptionsProvider ensures that its resource
		// descriptions are always associated with a (singleton) project description, so that this container manager will always
		// succeed in its lookup. 
		binder.bind(IContainer.Manager).to(ProjectDescriptionBasedContainerManager)  
		binder.bind(AbstractFileSystemAccess).to(JavaIoFileSystemAccess)
		binder.bind(IJavaCompiler).to(EclipseJavaCompiler)		
		
		binder.bind(IWebResourceSetProvider).to(CustomWebResourceSetProvider) // makes sure the XtextWebDocuments get the same resource set as the index uses
	}

}
