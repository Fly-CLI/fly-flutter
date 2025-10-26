import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Fly CLI',
  description: 'The first AI-native Flutter CLI tool - develop at the speed of thought',
  
  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
    ['meta', { name: 'theme-color', content: '#3c82f6' }],
  ],

  themeConfig: {
    logo: '/logo.svg',
    
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/getting-started' },
      { text: 'AI Integration', link: '/ai-integration/overview' },
      { text: 'Migration', link: '/migration/very-good-cli' },
      { text: 'API', link: '/api/fly-core' },
      { text: 'Examples', link: '/examples/minimal-example' },
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Installation', link: '/guide/installation' },
            { text: 'Quickstart', link: '/guide/quickstart' },
            { text: 'Templates', link: '/guide/templates' },
            { text: 'Commands', link: '/guide/commands' },
          ]
        }
      ],
      '/ai-integration/': [
        {
          text: 'AI Integration',
          items: [
            { text: 'Overview', link: '/ai-integration/overview' },
            { text: 'JSON Schemas', link: '/ai-integration/json-schemas' },
            { text: 'Manifest Format', link: '/ai-integration/manifest-format' },
            { text: 'Examples', link: '/ai-integration/examples' },
            { text: 'AI Agents', link: '/ai-integration/agents' },
          ]
        }
      ],
      '/migration/': [
        {
          text: 'Migration Guides',
          items: [
            { text: 'From Very Good CLI', link: '/migration/very-good-cli' },
            { text: 'From Stacked CLI', link: '/migration/stacked-cli' },
            { text: 'From Vanilla Flutter', link: '/migration/vanilla-flutter' },
          ]
        }
      ],
      '/api/': [
        {
          text: 'API Reference',
          items: [
            { text: 'fly_core', link: '/api/fly-core' },
            { text: 'fly_networking', link: '/api/fly-networking' },
            { text: 'fly_state', link: '/api/fly-state' },
          ]
        }
      ],
      '/examples/': [
        {
          text: 'Examples',
          items: [
            { text: 'Minimal Example', link: '/examples/minimal-example' },
            { text: 'Riverpod Example', link: '/examples/riverpod-example' },
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/fly-cli/fly' },
      { icon: 'twitter', link: 'https://twitter.com/fly_cli' },
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2024 Fly CLI'
    },

    search: {
      provider: 'local'
    },

    editLink: {
      pattern: 'https://github.com/fly-cli/fly/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    },

    lastUpdated: {
      text: 'Last updated',
      formatOptions: {
        dateStyle: 'short',
        timeStyle: 'medium'
      }
    }
  },

  markdown: {
    theme: {
      light: 'github-light',
      dark: 'github-dark'
    },
    lineNumbers: true
  },

  vite: {
    define: {
      __VUE_OPTIONS_API__: false,
      __VUE_PROD_DEVTOOLS__: false
    }
  }
})
