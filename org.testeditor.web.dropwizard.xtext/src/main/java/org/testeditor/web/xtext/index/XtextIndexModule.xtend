package org.testeditor.web.xtext.index

import com.google.inject.AbstractModule
import javax.inject.Inject
import org.eclipse.xtext.resource.IResourceDescriptions

class XtextIndexModule extends AbstractModule {

	@Inject XtextIndex index

	override protected configure() {
		binder.bind(IResourceDescriptions).toInstance(index)
	}

}
