package org.testeditor.web.xtext.index

import com.google.inject.AbstractModule
import javax.inject.Inject
import org.eclipse.xtext.builder.standalone.IIssueHandler
import org.eclipse.xtext.builder.standalone.compiler.EclipseJavaCompiler
import org.eclipse.xtext.builder.standalone.compiler.IJavaCompiler
import org.eclipse.xtext.generator.AbstractFileSystemAccess
import org.eclipse.xtext.generator.JavaIoFileSystemAccess
import org.eclipse.xtext.resource.IResourceDescriptions
import org.eclipse.xtext.web.server.model.IWebResourceSetProvider
import org.testeditor.web.dropwizard.xtext.validation.ValidationMarkerUpdater

class XtextIndexModule extends AbstractModule {

	@Inject XtextIndex index

	override protected configure() {
		val resourceSetProvider = new CustomWebResourceSetProvider(index)
		binder.bind(IResourceDescriptions).toInstance(index)
		binder.bind(AbstractFileSystemAccess).to(JavaIoFileSystemAccess).asEagerSingleton
		binder.bind(IJavaCompiler).to(EclipseJavaCompiler)
		binder.bind(IIssueHandler).to(ValidationMarkerUpdater)
		binder.bind(IWebResourceSetProvider).toInstance(resourceSetProvider) // makes sure the XtextWebDocuments get the same resource set as the index uses
	}

}
