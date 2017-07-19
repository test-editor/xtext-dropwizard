package org.xtext.example.mydsl.web

import javax.inject.Inject
import org.testeditor.web.dropwizard.xtext.XtextApplication

class MyDslApplication extends XtextApplication<MyDslConfiguration> {

	@Inject MyDslWebSetup setup
	
	override protected getLanguageSetups() {
		return #[setup]
	}
	
}