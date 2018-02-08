package org.testeditor.web.xtext.index

import com.google.inject.AbstractModule
import javax.inject.Inject
import org.eclipse.xtext.builder.standalone.IIssueHandler
import org.eclipse.xtext.builder.standalone.IIssueHandler.DefaultIssueHandler
import org.eclipse.xtext.builder.standalone.compiler.EclipseJavaCompiler
import org.eclipse.xtext.builder.standalone.compiler.IJavaCompiler
import org.eclipse.xtext.generator.AbstractFileSystemAccess
import org.eclipse.xtext.generator.JavaIoFileSystemAccess
import org.eclipse.xtext.resource.IResourceDescriptions
import org.eclipse.xtext.web.server.model.IWebResourceSetProvider
import org.eclipse.xtext.common.types.xtext.ClasspathBasedTypeScope
import org.eclipse.xtext.scoping.IScope

class XtextIndexModule extends AbstractModule {

	@Inject XtextIndex index

	override protected configure() {
		val resourceSetProvider = new CustomWebResourceSetProvider 
		resourceSetProvider.initWith(index)		
		binder.bind(IResourceDescriptions).toInstance(index)
		binder.bind(AbstractFileSystemAccess).to(JavaIoFileSystemAccess).asEagerSingleton
		binder.bind(IJavaCompiler).to(EclipseJavaCompiler)
		binder.bind(IIssueHandler).to(DefaultIssueHandler)
		binder.bind(IWebResourceSetProvider).toInstance(resourceSetProvider)
		// binder.bind(IScope).to(ClasspathBasedTypeScope)
	}

}
