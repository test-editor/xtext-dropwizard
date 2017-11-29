package org.xtext.example.mydsl.web

import org.testeditor.web.dropwizard.xtext.XtextApplication

class MyDslApplication extends XtextApplication<MyDslConfiguration> {

	override protected getLanguageSetups() {
		return #[new MyDslWebSetup]
	}
	
}