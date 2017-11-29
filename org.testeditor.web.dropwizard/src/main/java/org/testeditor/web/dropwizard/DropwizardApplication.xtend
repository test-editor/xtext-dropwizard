package org.testeditor.web.dropwizard

import com.google.inject.Inject
import com.google.inject.Module
import com.google.inject.servlet.ServletScopes
import com.google.inject.util.Modules
import com.hubspot.dropwizard.guice.GuiceBundle
import io.dropwizard.Application
import io.dropwizard.Configuration
import io.dropwizard.auth.AuthValueFactoryProvider
import io.dropwizard.setup.Bootstrap
import io.dropwizard.setup.Environment
import java.util.EnumSet
import java.util.List
import javax.servlet.DispatcherType
import org.eclipse.jetty.servlets.CrossOriginFilter
import org.glassfish.jersey.server.filter.RolesAllowedDynamicFeature
import org.testeditor.web.dropwizard.auth.JWTAuthFilter
import org.testeditor.web.dropwizard.auth.User
import org.testeditor.web.dropwizard.auth.UserProvider

import static org.eclipse.jetty.servlets.CrossOriginFilter.*

abstract class DropwizardApplication<T extends Configuration> extends Application<T> {

	@Inject JWTAuthFilter.Builder authFilterBuilder

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
	 * Copied from org.eclipse.xtext.util.Modules2
	 */
	protected static def Module mixin(Module... modules) {
		if (modules.length == 0) {
			return Modules.EMPTY_MODULE
		}
		var current = modules.get(0)
		for (var i = 1; i < modules.length; i++) {
			current = Modules.override(current).with(modules.get(i))
		}
		return current
	}

	protected def void configureCorsFilter(T configuration, Environment environment) {
		environment.servlets.addFilter("CORS", CrossOriginFilter) => [
			// Configure CORS parameters
			setInitParameter(ALLOWED_ORIGINS_PARAM, "*")
			setInitParameter(ALLOWED_HEADERS_PARAM, "*")
			setInitParameter(ALLOWED_METHODS_PARAM, "OPTIONS,GET,PUT,POST,DELETE,HEAD")
			setInitParameter(ALLOW_CREDENTIALS_PARAM, "true")

			// Add URL mapping
			addMappingForUrlPatterns(EnumSet.allOf(DispatcherType), true, "/*")

			// from https://stackoverflow.com/questions/25775364/enabling-cors-in-dropwizard-not-working
			// DO NOT pass a preflight request to down-stream auth filters
			// unauthenticated preflight requests should be permitted by spec
			setInitParameter(CrossOriginFilter.CHAIN_PREFLIGHT_PARAM, "false");
		]
	}

	protected def void configureAuthFilter(T configuration, Environment environment) {
		val filter = authFilterBuilder.buildAuthFilter
		environment.jersey => [
			register(filter)
			register(RolesAllowedDynamicFeature)
			register(new AuthValueFactoryProvider.Binder(User))
		]
	}

}
