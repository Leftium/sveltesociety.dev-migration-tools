<script lang="ts">
	import githubJson from '$lib/data/github.json';
	import { onMount } from 'svelte';
	import { SvelteSet } from 'svelte/reactivity';

	let checkedRepos = new SvelteSet<string>();

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

	function handleCheckboxChange(url: string, checked: boolean) {
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
		} else {
			checkedRepos.delete(url);
		}
		localStorage.setItem('checked-repos', JSON.stringify(Array.from(checkedRepos)));
	}
</script>

<div class="grid-container">
	{#each Object.keys(githubJson) as githubUrl, index}
		{@const ownerRepo = githubUrl.replace('https://github.com/', '')}
		<div class="grid-row">
			<div class="index">{index + 1}</div>
			<div class="checkbox">
				<input
					type="checkbox"
					checked={checkedRepos.has(githubUrl)}
					onchange={(e) => handleCheckboxChange(githubUrl, e.currentTarget.checked)}
				/>
			</div>
			<div class="repo">
				<a href={githubUrl} target="_blank">{ownerRepo}</a>
			</div>
		</div>
	{/each}
</div>

<style>
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
	}

	.checkbox {
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.repo {
		padding-left: 0.5rem;
	}
</style>
