package org.testeditor.web.dropwizard.xtext

import com.fasterxml.jackson.annotation.JsonProperty
import org.eclipse.xtend.lib.annotations.Accessors
import org.hibernate.validator.constraints.NotEmpty
import org.testeditor.web.dropwizard.DropwizardApplicationConfiguration

@Accessors
public class XtextConfiguration extends DropwizardApplicationConfiguration {

	@NotEmpty @JsonProperty
	String localRepoFileRoot

	@NotEmpty @JsonProperty
	String remoteRepoUrl

}
