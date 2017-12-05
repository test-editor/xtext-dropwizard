package org.testeditor.web.dropwizard.testing

import com.google.inject.Guice
import com.google.inject.Injector
import com.google.inject.Module
import com.google.inject.util.Modules
import de.xtendutils.junit.AssertionHelper
import java.util.List
import javax.inject.Inject
import org.junit.Before
import org.mockito.MockitoAnnotations
import org.slf4j.Logger
import org.slf4j.LoggerFactory

/**
 * Abstract dependency-injection aware test class for Xtext tests.
 * We don't want to use the XtextRunner as this limits us to not
 * use e.g. parameterized tests.
 */
abstract class AbstractTest {

	@Inject Injector injector

	@Inject protected extension AssertionHelper

	/** Subclass-aware logger. */
	protected extension Logger logger = LoggerFactory.getLogger(getClass())

	@Before
	def void performInjection() {
		MockitoAnnotations.initMocks(this)
		if (injector === null) {
			injector = createInjector
			injector.injectMembers(this)
		} // else: already injection aware
	}

	protected def Injector createInjector() {
		val modules = newLinkedList()
		modules.collectModules
		return Guice.createInjector(modules.mixin)
	}

	protected def void collectModules(List<Module> modules) {
	}

	/**
	 * Inspired by org.eclipse.xtext.util.Modules2
	 */
	protected static def Module mixin(Module... modules) {
		val seed = Modules.EMPTY_MODULE
		return modules.fold(seed, [ current, module |
			return Modules.override(current).with(module)
		])
	}

}
