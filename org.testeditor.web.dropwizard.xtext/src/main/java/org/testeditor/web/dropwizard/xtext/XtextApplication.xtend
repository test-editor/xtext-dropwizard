package org.testeditor.web.dropwizard.xtext

import io.dropwizard.Configuration
import io.dropwizard.setup.Environment
import java.util.List
import org.eclipse.jetty.server.session.SessionHandler
import org.eclipse.xtext.ISetup
import org.testeditor.web.dropwizard.DropwizardApplication

abstract class XtextApplication<T extends Configuration> extends DropwizardApplication<T> {

	override run(T configuration, Environment environment) throws Exception {
		super.run(configuration, environment)
		configureXtextServices(configuration, environment)
	}

	/**
	 * Adds the Xtext servlet and configures a session handler.
	 */
	protected def void configureXtextServices(T configuration, Environment environment) {
		languageSetups.forEach[createInjectorAndDoEMFRegistration]
		environment.jersey.register(XtextServiceResource)
		environment.servlets.sessionHandler = new SessionHandler
	}

	abstract protected def List<ISetup> getLanguageSetups()

}
