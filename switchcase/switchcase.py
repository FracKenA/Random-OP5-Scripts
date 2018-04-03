#!/usr/bin/env python

import argparse
import requests
import json
import logging
import csv


def save_work(server_url, ssl_check, auth_pair):
    logger = logging.getLogger(__name__)
    server_target = '/'.join(
        [
            server_url,
            "api",
            "config",
            "change",
        ]
    )
    print("Server target: {0}".format(server_target))
    print("SSL Check: {0}".format(ssl_check))
    print("Auth Pair: {0}".format(auth_pair))
    http_post_save = requests.post(
        server_target,
        data=json.dumps({}),
        verify=ssl_check,
        auth=auth_pair,
        headers={'content-type': 'application/json'}
    )
    logger.info('Header: {0}'.format(http_post_save.headers))
    logger.info('Request: {0}'.format(http_post_save.request))

    if http_post_save.status_code == 200 \
       or http_post_save.status_code == 201:
        print("Save status: {0}: {1}".format(
            http_post_save.status_code,
            http_post_save.text
        ))
        logger.info('Text: {0}: {1}'.format(
            http_post_save.status_code,
            http_post_save.text
        ))
    else:
        print("Save status: {0}: {1}".format(
            http_post_save.status_code,
            http_post_save.text
        ))
        logger.info('Text: {0}: {1}'.format(
            http_post_save.status_code,
            http_post_save.text
        ))
        http_post_save.raise_for_status()


def main():
    log_format = ':'.join(
        [
            '%(asctime)s',
            '%(levelname)s',
            '%(filename)s',
            '%(funcName)s',
            '%(lineno)s',
            '%(message)s',
        ]
    )
    logging.basicConfig(
        format=log_format,
        level=logging.INFO,
        filename="switchcase.log"
    )
    logger = logging.getLogger(__name__)

    ssl_check = True
    description = "Switches the case of hosts in OP5 Monitor."
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument(
        "listfile",
        help="File containing the hosts."
    )
    parser.add_argument(
        "account",
        help="Account to log into OP5 Monitor."
    )
    parser.add_argument(
        "password",
        help="Account password for OP5 Monitor."
    )
    parser.add_argument(
        "-n",
        "--nop",
        action='store_true',
        help="Dry run, no operations are executed."
    )
    parser.add_argument(
        "-p",
        "--pop",
        action='store_true',
        help="Partial operations, don't save anything."
    )
    parser.add_argument(
        "-d",
        "--dest-url",
        dest='url',
        default="https://localhost",
        help="The URL of the OP5 installation. Default: https://localhost"
    )
    parser.add_argument(
        '--nossl',
        action='store_true',
        help="Supress SSL warning."
    )
    parser.add_argument(
        '-l',
        '--lower',
        action='store_true',
        help="Switch case to lowercase."
    )
    parser.add_argument(
        '-u',
        '--upper',
        action='store_true',
        help="Switch case to uppercase."
    )
    parser.add_argument(
        '-i',
        '--save-interval',
        type=int,
        default=20,
        dest="save_interval",
        help="Sets the interval between saves."
    )
    args = parser.parse_args()

    # TODO: Figure out if argparse can deal with this.
    if not args.lower and not args.upper:
        logger.error("No cases selected. Please, pick one.")
        print("No cases selected. Please, pick one.")
        return 10
    elif args.lower and args.upper:
        logger.error("Both cases selected. Please, pick one.")
        print("Both cases selected. Please, pick one.")
        return 10

    if args.nossl:
        print("Supressing SSL warnings...")
        ssl_check = False
        requests.packages.urllib3.disable_warnings()

    auth_pair = (args.account, args.password)
    server_target = "/".join(
        [
            args.url,
            'api',
            'config',
            'host',
        ]
    )
    http_header = {'content-type': 'application/json'}
    save_interval = args.save_interval
    save_check = 0

    with open(args.listfile, 'rU') as hostlist:
        reader = csv.reader(hostlist, delimiter=',')
        for line in reader:
            if len(line) != 2:
                logger.info("Skipping line number {0}.\n{1}".format(
                    reader.line_num,
                    line
                ))
                continue
            elif line[0] != line[1]:
                print("Adding line number {0}.\t{1}".format(
                    reader.line_num,
                    line
                ))
                logger.info("Adding line number {0}.\t{1}".format(
                    reader.line_num,
                    line
                ))
                if args.lower:
                    host_name = line[0].lower()
                elif args.upper:
                    host_name = line[0].upper()

                json_payload = json.dumps({"host_name": host_name})
                logger.info("JSON Payload: {0}".format(json_payload))
                logger.info("Server target: {0}/{1}".format(server_target,
                                                            line[0]))
                server_target_host = "/".join(
                    [
                        server_target,
                        requests.utils.quote(line[0])
                    ]
                )
                if not args.nop:
                    http_package = requests.patch(
                        server_target_host,
                        data=json_payload,
                        verify=ssl_check,
                        auth=auth_pair,
                        headers=http_header
                    )

                    logger.info('Header: {0}'.format(http_package.headers))
                    logger.info('Request: {0}'.format(http_package.request))
                    logger.info('Text: {0}'.format(http_package.text))

                if save_check < save_interval:
                    save_check += 1
                elif args.nop or args.pop:
                    logger.info("No op or partial op. Not saving.")
                    print("No op or partial op. Not saving.")
                else:
                    print("Saving work.")
                    logger.info("Saving work.")
                    save_work(args.url, ssl_check, auth_pair)
                    save_check = 0

    if args.nop or args.pop:
        print("No op or partial op. Not saving")
        logger.info("No op or partial op. Not saving.")
        print("No op or partial op. Not saving.")
    else:
        print("Saving work.")
        logger.info("Saving work.")
        save_work(args.url, ssl_check, auth_pair)

    return(0)


if __name__ == '__main__':
    main()
