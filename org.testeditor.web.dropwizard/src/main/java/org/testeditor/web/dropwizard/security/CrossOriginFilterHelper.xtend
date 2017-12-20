package org.testeditor.web.dropwizard.security

import io.dropwizard.setup.Environment
import java.util.EnumSet
import javax.servlet.DispatcherType
import javax.servlet.FilterRegistration
import org.eclipse.jetty.servlets.CrossOriginFilter
import org.slf4j.LoggerFactory
import org.testeditor.web.dropwizard.DropwizardApplicationConfiguration

import static java.lang.Boolean.FALSE
import static java.lang.Boolean.TRUE
import static org.eclipse.jetty.servlets.CrossOriginFilter.*

class CrossOriginFilterHelper<T extends DropwizardApplicationConfiguration> {

	static val logger = LoggerFactory.getLogger(CrossOriginFilterHelper)
	static val allowedHeaders = 'X-Requested-With,Content-Type,Accept,Origin,Authorization'
	static val allowedMethods = 'OPTIONS,GET,PUT,POST,DELETE,HEAD'

	def void configureCorsFilter(T configuration, Environment environment) {
		environment.servlets.addFilter("CORS", CrossOriginFilter) => [
			// Filter should be applied for all URLs
			addMappingForUrlPatterns(EnumSet.allOf(DispatcherType), true, "/*")

			// Configure CORS parameters
			val allowedOrigins = configuration.allowedOrigins ?: '*'
			configureCorsParameters(it, allowedOrigins)

			// See also http://download.eclipse.org/jetty/stable-9/apidocs/org/eclipse/jetty/servlets/CrossOriginFilter.html
			// Handle preflight-requests (HTTP-Method OPTIONS) without this filter
			setInitParameter(CrossOriginFilter.CHAIN_PREFLIGHT_PARAM, FALSE.toString);
		]
	}

	protected def void configureCorsParameters(FilterRegistration registration, String allowedOrigins) {
		logWarningForAnyAllowedOrigins(allowedOrigins)
		registration.setInitParameter(ALLOWED_ORIGINS_PARAM, allowedOrigins)
		registration.setInitParameter(ALLOWED_HEADERS_PARAM, allowedHeaders)
		registration.setInitParameter(ALLOWED_METHODS_PARAM, allowedMethods)
		registration.setInitParameter(ALLOW_CREDENTIALS_PARAM, TRUE.toString)
	}

	private def void logWarningForAnyAllowedOrigins(String allowedOrigins) {
		if (allowedOrigins == '*') {
			val message = String.format('''
				%n
				!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				!    allowedOrigins IS NOT CONFIGURED PROPERLY - YOUR USERS WILL BE AT RISK    !
				!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			''')
			logger.warn(message)
		}
	}

}
