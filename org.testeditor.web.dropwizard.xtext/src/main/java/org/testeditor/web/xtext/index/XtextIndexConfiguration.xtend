package org.testeditor.web.xtext.index

import com.fasterxml.jackson.annotation.JsonProperty
import io.dropwizard.Configuration
import org.hibernate.validator.constraints.NotEmpty

public class XtextIndexConfiguration extends Configuration {

	@NotEmpty var String localRepoFileRoot
	@NotEmpty var String remoteRepoUrl

	/**
	 * file location used as root for the local repo
	 */
	@JsonProperty
	def getLocalRepoFileRoot() {
		return localRepoFileRoot
	}

	@JsonProperty
	def setLocalRepoFileRoot(String localRepoFileRoot) {
		this.localRepoFileRoot = localRepoFileRoot
	}

	/**
	 * url to git repository that is to be used for this index
	 */
	@JsonProperty
	def getRemoteRepoUrl() {
		return remoteRepoUrl
	}

	@JsonProperty
	def setRemoteRepoUrl(String remoteRepoUrl) {
		this.remoteRepoUrl = remoteRepoUrl
	}

}
