package org.testeditor.web.dropwizard

import com.google.inject.Inject
import com.google.inject.Module
import com.google.inject.servlet.ServletScopes
import com.google.inject.util.Modules
import com.hubspot.dropwizard.guice.GuiceBundle
import io.dropwizard.Application
import io.dropwizard.auth.AuthValueFactoryProvider
import io.dropwizard.setup.Bootstrap
import io.dropwizard.setup.Environment
import java.util.List
import org.glassfish.jersey.server.filter.RolesAllowedDynamicFeature
import org.testeditor.web.dropwizard.auth.DefaultAuthDynamicFeature
import org.testeditor.web.dropwizard.auth.User
import org.testeditor.web.dropwizard.auth.UserProvider
import org.testeditor.web.dropwizard.security.CrossOriginFilterHelper

abstract class DropwizardApplication<T extends DropwizardApplicationConfiguration> extends Application<T> {

	@Inject DefaultAuthDynamicFeature authFilter
	@Inject CrossOriginFilterHelper<T> corsHelper

	override initialize(Bootstrap<T> bootstrap) {
		super.initialize(bootstrap)
		initializeInjection(bootstrap)
	}

	override run(T configuration, Environment environment) throws Exception {
		configureCorsFilter(configuration, environment)
		configureAuthFilter(configuration, environment)
	}

	/**
	 * Initializes the Guice injection for the Dropwizard application. Please note
	 * that this does not affect the individual language injectors unless they are
	 * child injectors of the injector that is created here.
	 */
	protected def void initializeInjection(Bootstrap<T> bootstrap) {
		val guiceBundle = createGuiceBundle
		bootstrap.addBundle(guiceBundle)
		guiceBundle.injector.injectMembers(this)
	}

	protected def GuiceBundle<T> createGuiceBundle() {
		val modules = newLinkedList
		collectModules(modules)
		val builder = GuiceBundle.<T>newBuilder
		builder.addModule(mixin(modules))
		builder.configClass = configurationClass
		return builder.build
	}

	/**
	 * Overwrite to add custom modules. Don't forget to call {@code super.collectModules(modules)}.
	 */
	protected def void collectModules(List<Module> modules) {
		modules += [ binder |
			binder.bind(User).toProvider(UserProvider).in(ServletScopes.REQUEST)
		]
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

	protected def void configureCorsFilter(T configuration, Environment environment) {
		corsHelper.configureCorsFilter(configuration, environment)
	}

	protected def void configureAuthFilter(T configuration, Environment environment) {
		environment.jersey => [
			register(authFilter.withConfiguration(configuration))
			register(RolesAllowedDynamicFeature)
			register(new AuthValueFactoryProvider.Binder(User))
		]
	}

}
