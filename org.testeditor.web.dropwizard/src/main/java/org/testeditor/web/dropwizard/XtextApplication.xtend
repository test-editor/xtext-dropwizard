package org.testeditor.web.dropwizard

import com.google.inject.Inject
import com.google.inject.Module
import com.hubspot.dropwizard.guice.GuiceBundle
import io.dropwizard.Application
import io.dropwizard.Configuration
import io.dropwizard.setup.Bootstrap
import io.dropwizard.setup.Environment
import java.util.EnumSet
import javax.servlet.DispatcherType
import org.eclipse.jetty.server.session.SessionHandler
import org.eclipse.jetty.servlet.ServletHolder
import org.eclipse.jetty.servlets.CrossOriginFilter

abstract class XtextApplication<T extends Configuration> extends Application<T> {

	@Inject XtextServiceServlet xtextServlet

	override initialize(Bootstrap<T> bootstrap) {
		super.initialize(bootstrap)
		initializeInjection(bootstrap)
	}

	override run(T configuration, Environment environment) throws Exception {
		configureXtextServices(configuration, environment)
		configureCorsFilter(configuration, environment)
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
		val modules = modules
		val builder = GuiceBundle.<T>newBuilder
		for (module : modules) {
			builder.addModule(module)
		}
		return builder.build
	}

	/**
	 * Add your modules here.
	 */
	protected def Iterable<Module> getModules() {
	}

	/**
	 * Adds the Xtext servlet and configures a session handler.
	 */
	protected def void configureXtextServices(T configuration, Environment environment) {
		environment.applicationContext => [
			val servletHolder = new ServletHolder(xtextServlet)
			addServlet(servletHolder, "/xtext-service/*")
		]
		environment.servlets.sessionHandler = new SessionHandler
	}

	protected def void configureCorsFilter(T configuration, Environment environment) {
		environment.servlets.addFilter("CORS", CrossOriginFilter) => [
			// Configure CORS parameters
			setInitParameter("allowedOrigins", "*")
			setInitParameter("allowedHeaders", "X-Requested-With,Content-Type,Accept,Origin")
			setInitParameter("allowedMethods", "OPTIONS,GET,PUT,POST,DELETE,HEAD")

			// Add URL mapping
			addMappingForUrlPatterns(EnumSet.allOf(DispatcherType), true, "/*")
		]
	}

}
