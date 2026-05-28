"use client"
import { useActionState } from 'react'
import { login } from '@/app/actions/auth'


import { Mail, Lock, Eye, UtensilsCrossed } from "lucide-react"
import { useState } from "react"

export default function Login() {
    const [showPassword, setShowPassword] = useState(false)
    const [state, action, pending] = useActionState(login, undefined)

    return (
        <div className="flex w-full h-screen">

            {/** Left Side: Image **/}
            <div className="hidden md:flex md:w-1/2 relative bg-surface-container-highest">
                <img
                    src="/img/login.jpg"
                    alt="Gourmet food flatlay"
                    className="absolute inset-0 w-full h-full object-cover"
                />
                <div className="absolute inset-0  from-inverse-surface/60 to-transparent" />
            </div>

            {/** Right Side: Form **/}
            <div className="w-full md:w-1/2 flex items-center justify-center overflow-y-auto px-5 py-10 md:px-16 bg-surface-container-lowest shadow-[0_0_40px_rgba(255,107,53,0.05)]">
                <div className="h-full w-full flex flex-col gap-10">

                    {/** Brand Header **/}
                    <div className="flex flex-col gap-3 text-center md:text-left">
                        <div className="flex items-center justify-center md:justify-start gap-3">
                            <div className="flex items-center justify-center w-12 h-12 rounded-xl bg-primary-container shadow-[0_4px_12px_rgba(255,107,53,0.35)]">
                                <UtensilsCrossed className="w-6 h-6 text-white" />
                            </div>
                            <h1 className="text-headline-lg text-on-background">Zest &amp; Savory</h1>
                        </div>
                        <h2 className="text-headline-md text-on-background">Admin Portal</h2>
                        <p className="text-body-md text-on-surface-variant">Sign in to manage operations and fleet.</p>
                    </div>

                    {/** Form **/}
                    <form className="flex flex-col gap-6" action={action}>

                        {/** Email **/}
                        <div className="flex flex-col gap-1">
                            <label className="text-label-md text-on-background" htmlFor="email">
                                Administrator Email
                            </label>
                            <div className="relative">
                                <div className="absolute inset-y-0 left-3 flex items-center pointer-events-none">
                                    <Mail className="w-5 h-5 text-on-surface-variant" />
                                </div>
                                {state?.error && (
                                <div className="px-4 py-3 rounded-lg bg-red-50 border border-red-200 text-red-700 text-sm">
                                {state.error}
                                    </div>
                                )}
                                <input
                                    id="email" name="email" type="email" required
                                    placeholder="admin@zestandsavory.com"
                                    className="w-full pl-10 pr-3 py-3 border border-outline-variant rounded-lg bg-surface text-on-background focus:outline-none focus:ring-2 focus:ring-primary-container focus:border-primary-container placeholder:text-on-surface-variant/50"
                                />
                            </div>
                        </div>

                        {/** Password **/}
                        <div className="flex flex-col gap-1">
                            <label className="text-label-md text-on-background" htmlFor="password">
                                Security Password
                            </label>
                            <div className="relative">
                                <div className="absolute inset-y-0 left-3 flex items-center pointer-events-none">
                                    <Lock className="w-5 h-5 text-on-surface-variant" />
                                </div>
                                <input
                                    id="password" name="password"
                                    type={showPassword ? "text" : "password"} required
                                    placeholder="••••••••"
                                    className="w-full pl-10 pr-10 py-3 border border-outline-variant rounded-lg bg-surface text-on-background focus:outline-none focus:ring-2 focus:ring-primary-container focus:border-primary-container placeholder:text-on-surface-variant/50"
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                    className="absolute inset-y-0 right-3 flex items-center text-on-surface-variant hover:text-primary transition-colors focus:outline-none"
                                >
                                    <Eye className="w-5 h-5" />
                                </button>
                            </div>
                        </div>


                        {/** Submit **/}
                        <button
                            type="submit"
                            disabled={pending}
                            className="w-full py-3 px-4 rounded-full shadow-[0_4px_12px_rgba(255,107,53,0.3)] text-white font-semibold bg-primary-container hover:bg-primary focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-container transition-all active:scale-[0.98]"
                        >
                            {pending ? 'Signing in...' : 'Login'}
                        </button>


                    </form>

                    {/** Footer **/}
                    <div className="text-center pt-6 border-t border-surface-variant">
                        <p className="text-body-sm text-on-surface-variant">
                            Need help accessing your account?{" "}
                            <a href="#" className="text-label-md text-primary-container hover:text-primary transition-colors">
                                Contact IT Support
                            </a>
                        </p>
                    </div>

                </div>
            </div>

        </div>
    )
}
