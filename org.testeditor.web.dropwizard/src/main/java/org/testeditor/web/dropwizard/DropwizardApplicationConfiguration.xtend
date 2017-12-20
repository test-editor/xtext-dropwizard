package org.testeditor.web.dropwizard

import com.fasterxml.jackson.annotation.JsonProperty
import io.dropwizard.Configuration
import org.eclipse.xtend.lib.annotations.Accessors
import org.hibernate.validator.constraints.NotEmpty

@Accessors
class DropwizardApplicationConfiguration extends Configuration {

	@NotEmpty @JsonProperty
	String allowedOrigins

	@JsonProperty
	String apiToken

}
