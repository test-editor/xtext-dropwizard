package org.testeditor.web.xtext.index

import org.junit.Before
import com.google.inject.Guice

/**
 * provide default injection to members
 */
abstract class AbstractTestInjectingMembers {

	@Before
	def void setupInjection() {
		Guice.createInjector.injectMembers(this)
	}

}
