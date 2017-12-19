package org.xtext.example.mydsl.web

import org.testeditor.web.dropwizard.xtext.testing.AbstractXtextIntegrationTest

abstract class AbstractMyDslApplicationIntegrationTest extends AbstractXtextIntegrationTest<MyDslConfiguration> {

	override protected getApplicationClass() {
		return MyDslApplication
	}

}
