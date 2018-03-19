package org.testeditor.web.xtext.index

import org.junit.BeforeClass
import org.testeditor.web.dropwizard.testing.AbstractTest
import org.xtext.example.mydsl.MyDslStandaloneSetup

/**
 * Registers the MyDsl language as an example language.
 */
abstract class AbstractTestWithExampleLanguage extends AbstractTest {

	protected static val MyDslStandaloneSetup myDslSetup = new MyDslStandaloneSetup

	@BeforeClass
	static def void registerSampleLanguage() {
		myDslSetup.createInjectorAndDoEMFRegistration
	}

}
