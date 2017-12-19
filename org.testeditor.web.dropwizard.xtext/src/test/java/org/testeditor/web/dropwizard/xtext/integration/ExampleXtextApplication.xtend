package org.testeditor.web.dropwizard.xtext.integration

import org.testeditor.web.dropwizard.xtext.XtextApplication
import org.testeditor.web.dropwizard.xtext.XtextConfiguration
import org.testeditor.web.xtext.index.XtextIndexModule

class ExampleXtextApplication extends XtextApplication<XtextConfiguration> {

	override protected getLanguageSetups(XtextIndexModule indexModule) {
		return #[new MyDslWebModule(indexModule)]
	}

}
