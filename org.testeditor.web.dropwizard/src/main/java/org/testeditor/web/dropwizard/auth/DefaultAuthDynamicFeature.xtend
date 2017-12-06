package org.testeditor.web.dropwizard.auth

import java.lang.annotation.Annotation
import javax.inject.Inject
import javax.ws.rs.container.DynamicFeature
import javax.ws.rs.container.ResourceInfo
import javax.ws.rs.core.FeatureContext
import org.testeditor.web.dropwizard.DropwizardApplicationConfiguration

/**
 * All methods are protected by default and are accessible with valid jwt token only!
 * Methods explicitly annotated with @ApiTokenAuth are accessible with api token only!
 * Methods explicitly annotated with @NoAuth are accessible without authentication
 *  
 * see http://www.dropwizard.io/1.2.0/docs/manual/auth.html#chained-factories
 * and http://dinomite.net/blog/2016/05/18/optional-authentication-with-dropwizard/
 */
class DefaultAuthDynamicFeature implements DynamicFeature {

	DropwizardApplicationConfiguration configuration

	@Inject JWTAuthFilter.Builder authFilterBuilder
	@Inject ApiTokenAuthFilter.Builder apiTokenAuthFilterBuilder

	override configure(ResourceInfo resourceInfo, FeatureContext context) {
		if (resourceInfo.isAnnotatedWith(NoAuth)) {
			return // no authentication is checked
		} else if (resourceInfo.isAnnotatedWith(ApiTokenAuth)) {
			if (configuration.apiToken.nullOrEmpty) {
				throw new RuntimeException('''dropwizard configuration exception: missing field 'apiToken' for accessing «(resourceInfo.resourceClass?.toString)?:(resourceInfo.resourceMethod?.toString)».''')
			}
			context.register(apiTokenAuthFilterBuilder.withApiToken(configuration.apiToken).buildAuthFilter)
		} else {
			context.register(authFilterBuilder.buildAuthFilter)
		}

	}

	def DefaultAuthDynamicFeature withConfiguration(DropwizardApplicationConfiguration configuration) {
		this.configuration = configuration
		return this
	}

	private def boolean isAnnotatedWith(ResourceInfo resourceInfo, Class<? extends Annotation> annotation) {
		val method = resourceInfo.resourceMethod
		val clazz = resourceInfo.resourceClass
		return method?.getAnnotation(annotation) !== null || clazz?.getAnnotation(annotation) !== null
	}

}
