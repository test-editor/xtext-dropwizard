package org.testeditor.web.xtext.index.persistence

import java.io.File
import javax.inject.Inject
import org.eclipse.jgit.api.Git
import org.junit.Before
import org.junit.Rule
import org.junit.rules.ExpectedException
import org.junit.rules.TemporaryFolder
import org.mockito.InjectMocks
import org.mockito.Mock
import org.testeditor.web.dropwizard.testing.AbstractTest
import org.testeditor.web.dropwizard.testing.files.FileTestUtils
import org.testeditor.web.dropwizard.testing.git.JGitTestUtils
import org.testeditor.web.xtext.index.persistence.GitService.GitAccess

import static org.mockito.ArgumentMatchers.*
import static org.mockito.Mockito.when

abstract class AbstractGitTest extends AbstractTest {

	@Mock protected GitAccess gitAccess

	@InjectMocks protected GitService gitService

	@Rule public ExpectedException expectedException = ExpectedException.none

	@Rule public TemporaryFolder localRepoTemporaryFolder = new TemporaryFolder
	@Rule public TemporaryFolder remoteRepoTemporaryFolder = new TemporaryFolder
	protected File localRepoRoot
	protected File remoteRepoRoot
	protected Git remoteGit
	protected String branchName

	@Inject protected extension JGitTestUtils
	@Inject protected extension FileTestUtils

	@Before
	def void initializeVariables() {
		localRepoRoot = localRepoTemporaryFolder.root
		remoteRepoRoot = remoteRepoTemporaryFolder.root
		branchName = 'master'
		remoteGit = Git.init.setDirectory(remoteRepoRoot).call
		remoteGit.commit.setMessage("Initial commit").call // only after this initial commit a 'master' branch is present
	}
	
	@Before
	def void initializeGitAccess() {
		when(gitAccess.open(any)).thenCallRealMethod
		when(gitAccess.cloneRepository).thenCallRealMethod
	}

}
