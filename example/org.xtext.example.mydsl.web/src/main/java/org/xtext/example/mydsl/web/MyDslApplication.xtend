package org.xtext.example.mydsl.web

import org.testeditor.web.dropwizard.xtext.XtextApplication
import org.testeditor.web.xtext.index.XtextIndexModule

class MyDslApplication extends XtextApplication<MyDslConfiguration> {

	override protected getLanguageSetups(XtextIndexModule indexModule) {
		return #[new MyDslWebSetup(indexModule)]
	}

}
