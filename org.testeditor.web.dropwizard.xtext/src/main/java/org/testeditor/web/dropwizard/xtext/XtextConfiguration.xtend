package org.testeditor.web.dropwizard.xtext

import com.fasterxml.jackson.annotation.JsonProperty
import io.dropwizard.Configuration
import org.eclipse.xtend.lib.annotations.Accessors
import org.hibernate.validator.constraints.NotEmpty

@Accessors
public class XtextConfiguration extends Configuration {

	@NotEmpty @JsonProperty
	String localRepoFileRoot

	@NotEmpty @JsonProperty
	String remoteRepoUrl

}
