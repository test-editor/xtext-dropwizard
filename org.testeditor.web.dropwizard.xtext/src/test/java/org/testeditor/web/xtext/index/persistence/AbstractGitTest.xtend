package org.testeditor.web.xtext.index.persistence

import java.io.File
import javax.inject.Inject
import org.eclipse.jgit.api.Git
import org.junit.Before
import org.junit.Rule
import org.junit.rules.ExpectedException
import org.junit.rules.TemporaryFolder
import org.mockito.InjectMocks
import org.testeditor.web.dropwizard.testing.AbstractTest
import org.testeditor.web.dropwizard.testing.files.FileTestUtils
import org.testeditor.web.dropwizard.testing.git.JGitTestUtils

class AbstractGitTest extends AbstractTest {

	@InjectMocks protected GitService gitService

	@Rule public ExpectedException expectedException = ExpectedException.none

	@Rule public TemporaryFolder localRepoTemporaryFolder = new TemporaryFolder
	@Rule public TemporaryFolder remoteRepoTemporaryFolder = new TemporaryFolder
	protected File localRepoRoot
	protected File remoteRepoRoot
	protected Git remoteGit

	@Inject protected extension JGitTestUtils
	@Inject protected extension FileTestUtils

	@Before
	def void initializeVariables() {
		localRepoRoot = localRepoTemporaryFolder.root
		remoteRepoRoot = remoteRepoTemporaryFolder.root
		remoteGit = Git.init.setDirectory(remoteRepoRoot).call
		remoteGit.commit.setMessage("Initial commit").call // only after this initial commit a 'master' branch is present
	}

}
