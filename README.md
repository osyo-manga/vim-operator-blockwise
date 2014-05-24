# vim-operator-blockwise

幅が違う textobj を矩形操作するためのプラグインです。


## Example setting

```vim
" YYiw でカーソルから下の行に向かって iw にマッチしなくなるまでの範囲をヤンクします

" ヤンク
nmap YY <Plug>(operator-blockwise-yank-head)
" 削除
nmap DD <Plug>(operator-blockwise-delete-head)
" 変更
nmap CC <Plug>(operator-blockwise-change-head)
```

## Screencapture

`<Plug>(operator-blockwise-delete-head)i"`

![dd](https://cloud.githubusercontent.com/assets/214488/3074723/8f568f68-e34f-11e3-84b5-340558aaa021.gif)

`<Plug>(operator-blockwise-change-head)iw`

![cc](https://cloud.githubusercontent.com/assets/214488/3074722/7c37cbcc-e34f-11e3-96a4-dc01f5ec660d.gif)





