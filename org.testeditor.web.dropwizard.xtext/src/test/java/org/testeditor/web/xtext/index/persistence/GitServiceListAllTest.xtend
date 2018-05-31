package org.testeditor.web.xtext.index.persistence

import org.eclipse.jgit.revwalk.RevCommit
import org.junit.Before
import org.junit.Test
import org.eclipse.jgit.api.Git

class GitServiceListAllTest extends AbstractGitTest {

	@Before
	def void setupGitService() {
		gitService.init(localRepoRoot.path, remoteRepoRoot.path, branchName)
	}

	@Test
	def void committingSingleFileResultInOneListedFile() {
		// given
		writeRemoteAndCommit('example.txt', 'boring content', 'first commit')
		gitService.pull

		// when
		val allFiles = gitService.listAllCommittedFiles

		// then
		allFiles.assertSingleElement.assertEquals('example.txt')
	}

	@Test
	def void committingOneFileTwoTimesResultsInOneListedFile() {
		// given
		writeRemoteAndCommit('example.txt', 'boring content', 'first commit')
		writeRemoteAndCommit('example.txt', 'amazing content', 'second commit')
		gitService.pull

		// when
		val allFiles = gitService.listAllCommittedFiles

		// then
		allFiles.assertSingleElement.assertEquals('example.txt')
	}

	@Test
	def void committingTwoDifferentFilesResultsInTwoListedFiles() {
		// given
		writeRemoteAndCommit('example.txt', 'boring content', 'first commit')
		writeRemoteAndCommit('readme.md', 'amazing content', 'second commit')
		gitService.pull

		// when
		val allFiles = gitService.listAllCommittedFiles

		// then
		allFiles.assertSize(2) => [
			exists[equals('example.txt')].assertTrue
			exists[equals('readme.md')].assertTrue
		]
	}

	@Test
	def void committingDeepStructureFileStructureResultsInTreeInListedFiles() {
		// given
		val expectedAndCommittedFiles = #[ //
			"README.md", //
			"src/main/java/org/testeditor/Example.java", //
			"src/test/java/org/testeditor/ExampleTest.java", //
			"src/test/resource/log4j2.xml", //
			".gitignore", //
			".travis.yml" //
		]
		expectedAndCommittedFiles.forEach [
			writeRemoteAndCommit('boring content', '''added file:«it»''')
		]
		gitService.pull

		// when
		val allFiles = gitService.listAllCommittedFiles

		// then
		allFiles.assertSize(expectedAndCommittedFiles.size) => [ listedFiles |
			#[ //
				"README.md", //
				"src/main/java/org/testeditor/Example.java", //
				"src/test/java/org/testeditor/ExampleTest.java", //
				"src/test/resource/log4j2.xml", //
				".gitignore", //
				".travis.yml" //
			].forEach [ expectedFile |
				listedFiles.exists[equals(expectedFile)].assertTrue('''file '«expectedFile»' not found''')
			]
		]
	}

	@Test
	def void uncommittedLocalFilesAreNotListed() {
		// when
		writeRemoteAndCommit('example.txt', 'boring content', 'first commit')
		gitService.pull

		write(localRepoRoot, 'README.md', '')

		// when
		val allFiles = gitService.listAllCommittedFiles

		// then
		allFiles.assertSingleElement.assertEquals('example.txt')
	}

	@Test
	def void committedLocalFilesAreListedToo() {
		// when
		writeRemoteAndCommit('example.txt', 'boring content', 'first commit')
		gitService.pull

		val localGit = Git.init.setDirectory(localRepoRoot).call
		write(localRepoRoot, 'README.md', '')
		addAndCommit(localGit, 'README.md', 'local commit')

		// when
		val allFiles = gitService.listAllCommittedFiles

		// then
		allFiles.assertSize(2) => [
			exists[equals('README.md')].assertTrue
			exists[equals('example.txt')].assertTrue
		]
	}
	
	@Test
	def void addedLocalFilesAreNotListed() {
		writeRemoteAndCommit('example.txt', 'boring content', 'first commit')
		gitService.pull

		val localGit = Git.init.setDirectory(localRepoRoot).call
		write(localRepoRoot, 'README.md', '')
		localGit.add.addFilepattern('README.md').call

		// when
		val allFiles = gitService.listAllCommittedFiles

		// then
		allFiles.assertSingleElement.equals('example.txt').assertTrue
	}

	private def RevCommit writeRemoteAndCommit(String fileName, String content, String commitMsg) {
		write(remoteRepoRoot, fileName, content)
		return addAndCommit(remoteGit, fileName, commitMsg)

	}

}
