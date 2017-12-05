package org.testeditor.web.xtext.index.persistence

import java.io.File
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.lib.Constants
import org.eclipse.jgit.revwalk.RevCommit
import org.eclipse.jgit.transport.URIish
import org.junit.Test

class GitServiceInitTest extends AbstractGitTest {

	@Test
	def void clonesRemoteRepositoryWhenUninitialized() {
		// given
		val remoteHead = createExampleFileOnRemote()

		// when
		gitService.init(localRepoRoot.path, remoteRepoRoot.path)

		// then
		val lastLocalCommit = Git.init.setDirectory(localRepoRoot).call.lastCommit
		lastLocalCommit.assertEquals(remoteHead)
		gitService.headTree.name().assertEquals(lastLocalCommit.tree.name())
	}

	@Test
	def void isExistingGitRepositoryReturnsTrueForExistingRepository() {
		// given
		Git.init.setDirectory(localRepoRoot).call

		// when + then
		gitService.isExistingGitRepository(localRepoRoot).assertTrue
	}

	@Test
	def void isExistingGitRepositoryReturnsFalseForEmptyFolder() {
		// when + then
		gitService.isExistingGitRepository(localRepoRoot).assertFalse
	}

	@Test
	def void canReusesExistingGitRepository() {
		// given
		val remoteHead = createExampleFileOnRemote()
		Git.cloneRepository.setDirectory(localRepoRoot).setURI(remoteRepoRoot.path).call

		// when
		gitService.init(localRepoRoot.path, remoteRepoRoot.path)

		// then
		gitService.git.lastCommit.assertEquals(remoteHead)
	}

	@Test
	def void failsOnExistingGitRepositoryWithWrongRemote() {
		// given
		val localGit = Git.init.setDirectory(localRepoRoot).call
		localGit.remoteAdd => [
			name = Constants.DEFAULT_REMOTE_NAME
			uri = new URIish('http://example.com')
			call
		]

		// when + then
		expectedException.expect(IllegalArgumentException)
		expectedException.expectMessage('The currently existing Git repository remote URL does not match the configured one.')
		gitService.init(localRepoRoot.path, remoteRepoRoot.path)
	}

	@Test
	def void throwsExceptionOnInvalidLocalRepoFileRoot() {
		// given
		write(localRepoRoot, 'demo.txt', 'test')
		val invalidLocalRepoFileRoot = new File(localRepoRoot, 'demo.txt').path

		// when + then
		expectedException.expect(IllegalArgumentException)
		expectedException.expectMessage('''Configured localRepoFileRoot=«invalidLocalRepoFileRoot» is not a directory!''')
		gitService.init(invalidLocalRepoFileRoot, remoteRepoRoot.path)
	}

	private def RevCommit createExampleFileOnRemote() {
		write(remoteRepoRoot, 'example.txt', 'dummy content')
		addAndCommit(remoteGit, 'example.txt', 'first commit')
		return remoteGit.lastCommit
	}

}
