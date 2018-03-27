package org.testeditor.web.dropwizard.xtext

import com.fasterxml.jackson.annotation.JsonProperty
import org.eclipse.xtend.lib.annotations.Accessors
import org.hibernate.validator.constraints.NotEmpty
import org.testeditor.web.dropwizard.DropwizardApplicationConfiguration

@Accessors
public class XtextConfiguration extends DropwizardApplicationConfiguration {

	@NotEmpty @JsonProperty
	String localRepoFileRoot = 'repo'
	
	@JsonProperty
	String[] indexSearchPaths = #['/src/main/java', '/src/test/java']
	
	@JsonProperty
	String[] indexClassPath = #['/build/classes/java/main']

	@NotEmpty @JsonProperty
	String remoteRepoUrl

	@JsonProperty
	String privateKeyLocation

	@JsonProperty
	String knownHostsLocation

}
