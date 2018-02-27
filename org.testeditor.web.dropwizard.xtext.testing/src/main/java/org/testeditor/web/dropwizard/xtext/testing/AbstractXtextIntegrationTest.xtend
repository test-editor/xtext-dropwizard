package org.testeditor.web.dropwizard.xtext.testing

import io.dropwizard.Configuration
import java.io.File
import java.io.IOException
import javax.ws.rs.client.Entity
import javax.ws.rs.client.Invocation
import javax.ws.rs.core.Form
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.revwalk.RevCommit
import org.junit.rules.RuleChain
import org.junit.rules.TemporaryFolder
import org.testeditor.web.dropwizard.testing.AbstractDropwizardIntegrationTest
import org.testeditor.web.dropwizard.testing.files.FileTestUtils
import org.testeditor.web.dropwizard.testing.git.JGitTestUtils

import static io.dropwizard.testing.ConfigOverride.config

abstract class AbstractXtextIntegrationTest<C extends Configuration> extends AbstractDropwizardIntegrationTest<C> {

	protected extension val FileTestUtils = new FileTestUtils
	protected extension val JGitTestUtils = new JGitTestUtils

	protected Git remoteGit
	protected val localRepoTemporaryFolder = new TemporaryFolder
	protected val remoteRepoTemporaryFolder = new TemporaryFolder {

		/** We need to initialize the Git repository right away, otherwise our bootstrapping will fail. */
		override create() throws IOException {
			super.create()
			remoteGit = Git.init.setDirectory(root).call
			initializeRemoteRepository(remoteGit, root)
		}

	}
	protected String apiToken = 'superSecretToken'

	new() {
		super()
		ruleChain = RuleChain.outerRule(remoteRepoTemporaryFolder).around(localRepoTemporaryFolder).around(dropwizardAppRule)
	}

	override protected createConfiguration() {
		val result = super.createConfiguration()
		result += config('localRepoFileRoot', [localRepoTemporaryFolder.root.path])
		result += config('remoteRepoUrl', [remoteRepoTemporaryFolder.root.path])
		result += config('apiToken', [apiToken])
		return result
	}
	
	protected def void initializeRemoteRepository(Git git, File parent) {
		writeToRemote('README.md', 'example')
	}

	protected def RevCommit writeToRemote(String file, String content) {
		write(remoteRepoTemporaryFolder.root, file, content)
		return addAndCommit(remoteGit, file, 'Add ' + file)
	}
	
	protected def RevCommit deleteOnRemote(String file) {
		val fileToDelete = new File(remoteRepoTemporaryFolder.root, file)
		fileToDelete.delete
		remoteGit.rm.addFilepattern(file).call
		return remoteGit.commit.setMessage('Delete ' + file).call
	}

	protected def Invocation createPostWithFullText(String url, String fullText) {
		val form = new Form('fullText', fullText)
		return createRequest(url).buildPost(Entity.form(form))
	}

	protected def Invocation createValidationRequest(String resourceId, String fullText) {
		val url = 'xtext-service/validate?resource=' + resourceId
		return createPostWithFullText(url, fullText)
	}
	
	protected def Invocation createValidationMarkerRequest(String resourceId) {
		val url = 'validation-markers?resource=' + resourceId
		return createRequest(url).buildGet()
	}
	
	protected def Invocation createValidationMarkerUpdateRequest() {
		val url = 'validation-markers/updates'
		return createRequest(url).buildGet()
	}
	
	protected def Invocation createValidationMarkerUpdateRequest(long lastAccessed) {
		val url = '''validation-markers/updates?lastAccessed=«lastAccessed»'''
		return createRequest(url).buildGet()
	}
}
