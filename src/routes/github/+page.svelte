<script lang="ts">
	import githubJson from '$lib/data/github.json';
	import { onMount } from 'svelte';
	import { SvelteSet } from 'svelte/reactivity';
	import FilterButtons from '$lib/components/FilterButtons.svelte';

	let checkedRepos = new SvelteSet<string>();
	let visibleUrls = $state(new Set(Object.keys(githubJson)));
	let showDuplicates = $state(false);

	const allRepoNames = Object.keys(githubJson).map(
		(url) => url.replace('https://github.com/', '').split('/')[1]
	);

	onMount(() => {
		const stored = localStorage.getItem('checked-repos');
		if (stored) {
			try {
				const parsed = JSON.parse(stored);
				parsed.forEach((url: string) => checkedRepos.add(url));
			} catch (err) {
				console.error('Failed to parse checked repos from localStorage:', err);
			}
		}
	});

	async function handleCheckboxChange(url: string, checked: boolean) {
		if (checked) {
			checkedRepos.add(url);
			navigator.clipboard.writeText(url).catch((err) => {
				console.error('Failed to copy to clipboard:', err);
			});
			window.open(url, 'GITHUB_ROOT');

			const ownerRepo = url.replace('https://github.com/', '');
			const params = new URLSearchParams({
				q: `repo:${ownerRepo} "svelte":`,
				type: 'code'
			});
			const searchUrl = `https://github.com/search?${params.toString()}`;
			window.open(searchUrl, 'GITHUB_SEARCH');

			const [owner, repo] = ownerRepo.split('/');

			try {
				const searchResponse = await fetch(
					`https://registry.npmjs.org/-/v1/search?text=${encodeURIComponent(repo)}&size=10`
				);
				const searchData = await searchResponse.json();

				console.log('Search results:', searchData);

				const matchingPackage = searchData.objects?.find((obj: any) => {
					const repoUrl = obj.package?.links?.repository;
					console.log('Checking repo URL:', repoUrl, 'against', url);
					if (!repoUrl) return false;

					const normalizedRepoUrl = repoUrl
						.toLowerCase()
						.replace('git+', '')
						.replace(/\.git$/, '');
					const normalizedUrl = url.toLowerCase();

					return normalizedRepoUrl === normalizedUrl;
				});

				console.log('Matching package:', matchingPackage);

				if (matchingPackage) {
					const packageName = matchingPackage.package.name;
					const npmUrl = `https://www.npmjs.com/package/${packageName}`;
					window.open(npmUrl, 'NPM_PACKAGE');
				}
			} catch (err) {
				console.error('Failed to search NPM registry:', err);
			}
		} else {
			checkedRepos.delete(url);
		}
		localStorage.setItem('checked-repos', JSON.stringify(Array.from(checkedRepos)));
	}
</script>

<div class="controls">
	<FilterButtons
		allItems={Object.keys(githubJson)}
		checkedItems={checkedRepos}
		onFilterChange={(set) => (visibleUrls = set)}
	/>
	<label>
		<input type="checkbox" bind:checked={showDuplicates} />
		Duplicates
	</label>
</div>

<div class="grid-container">
	{#each Object.keys(githubJson) as githubUrl, index}
		{@const ownerRepo = githubUrl.replace('https://github.com/', '')}
		{@const repoName = ownerRepo.split('/')[1]}
		{@const isDuplicate = allRepoNames.indexOf(repoName) !== index}
		<div
			class="grid-row"
			class:hidden={!visibleUrls.has(githubUrl) || (!showDuplicates && isDuplicate)}
		>
			<div class="index">{index + 1}</div>
			<div class="checkbox">
				<input
					type="checkbox"
					checked={checkedRepos.has(githubUrl)}
					onchange={(e) => handleCheckboxChange(githubUrl, e.currentTarget.checked)}
				/>
			</div>
			<div class="repo">
				{#if isDuplicate}⚠️&nbsp;{/if}
				<a href={githubUrl} target="_blank">{ownerRepo}</a>
			</div>
		</div>
	{/each}
</div>

<style>
	.controls {
		display: flex;
		align-items: center;
		gap: 1rem;
		margin-bottom: 1rem;
	}

	.grid-container {
		display: grid;
		gap: 0;
	}

	.grid-row {
		display: grid;
		grid-template-columns: 4rem 3rem 1fr;
		align-items: center;
		border-bottom: 1px solid var(--pico-muted-border-color);
		padding: 0.5rem 0;
	}

	.grid-row:last-child {
		border-bottom: none;
	}

	.index {
		text-align: right;
		padding-right: 1rem;
		color: var(--pico-muted-color);
		font-variant-numeric: tabular-nums;
	}

	.checkbox {
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.repo {
		padding-left: 0.5rem;
	}

	.hidden {
		display: none;
	}
</style>
