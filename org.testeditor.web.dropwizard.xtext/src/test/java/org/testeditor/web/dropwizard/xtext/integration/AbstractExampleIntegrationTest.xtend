package org.testeditor.web.dropwizard.xtext.integration

import org.testeditor.web.dropwizard.xtext.XtextConfiguration
import org.testeditor.web.dropwizard.xtext.testing.AbstractXtextIntegrationTest

abstract class AbstractExampleIntegrationTest extends AbstractXtextIntegrationTest<XtextConfiguration> {

	override protected getApplicationClass() {
		return ExampleXtextApplication
	}

}
