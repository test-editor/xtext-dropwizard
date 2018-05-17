package org.testeditor.web.xtext.index.persistence

import org.eclipse.jgit.diff.DiffEntry.ChangeType
import org.eclipse.jgit.revwalk.RevCommit
import org.junit.Before
import org.junit.Test

class GitServiceDiffTest extends AbstractGitTest {

	@Before
	def void setupGitService() {
		gitService.init(localRepoRoot.path, remoteRepoRoot.path, branchName)
	}

	@Test
	def void canCalculateDiffOfASimpleCommit() {
		// given
		val firstFile = 'example.txt'
		val firstCommit = createFirstCommitOnRemote.tree.name()
		val secondCommit = createSecondCommitOnRemote.tree.name()
		gitService.pull

		// when
		val differences = gitService.calculateDiff(firstCommit, secondCommit)

		// then
		differences.assertSingleElement => [
			changeType.assertEquals(ChangeType.MODIFY)
			oldPath.assertEquals(firstFile)
			newPath.assertEquals(firstFile)
		]
	}

	private def RevCommit createFirstCommitOnRemote() {
		write(remoteRepoRoot, 'example.txt', '')
		return addAndCommit(remoteGit, 'example.txt', 'first commit')
	}

	private def RevCommit createSecondCommitOnRemote() {
		write(remoteRepoRoot, 'example.txt', 'amazing content')
		return addAndCommit(remoteGit, 'example.txt', 'second commit')
	}

}
